#!/usr/bin/env bash
### Builds a headless bundle and runs the decore benchmarks, capturing the output.
###
### Usage, from the project root:
###   bash test/benchmark/run.sh [output_file] [repeats]
###
### Repeats run the suite again in a fresh process without rebuilding. Which traces
### LuaJIT compiles varies per process, which is worth a few tens of percent, so 3
### repeats and the best of them is a good default when comparing branches.
###
### Comparing two branches:
###   git checkout develop && bash test/benchmark/run.sh bench_develop.txt 3
###   git checkout shapes  && bash test/benchmark/run.sh bench_shapes.txt 3
###   lua test/benchmark/compare.lua bench_develop.txt bench_shapes.txt
###
### Set DEPLOYER to a local defold-deployer checkout to skip the download.

set -e

if [ ! -f ./game.project ]; then
	echo "Run this script from the project root"
	exit 1
fi

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo run)"
output="${1:-bench_${branch//\//_}.txt}"
repeats="${2:-1}"

case "$(uname -s)" in
	Darwin) platform="m" ;;
	Linux) platform="l" ;;
	*) platform="w" ;;
esac

# A build sitting in ./build/default shadows the bundled archive at runtime, and
# the editor builds the test collection there instead of the benchmark one
rm -rf ./build/default

deployer_args=("${platform}bd" --headless --settings ./test/bench.ini)

if [ -n "${DEPLOYER}" ]; then
	bash "${DEPLOYER}" "${deployer_args[@]}" 2>&1 | tee "${output}"
else
	deployer_url="https://raw.githubusercontent.com/Insality/defold-deployer/1/deployer.sh"
	curl -s "${deployer_url}" | bash -s "${deployer_args[@]}" 2>&1 | tee "${output}"
fi

if [ "${repeats}" -gt 1 ]; then
	artifact="$(sed -n 's/.*Build artifact: //p' "${output}" | tail -1 | tr -d '\r')"

	if [ -d "${artifact}/Contents/MacOS" ]; then
		binary="$(find "${artifact}/Contents/MacOS" -maxdepth 1 -type f -perm -u+x | head -1)"
	else
		binary="$(find "${artifact}" -maxdepth 1 -type f -perm -u+x | head -1)"
	fi

	if [ -z "${binary}" ]; then
		echo "Could not find the built executable, skipping the extra repeats"
	else
		for run in $(seq 2 "${repeats}"); do
			echo "Repeat ${run}/${repeats}"
			# Let the machine settle after the build, it skews the first samples
			sleep 5
			"${binary}" 2>&1 | tee -a "${output}"
		done
	fi
fi

echo ""
echo "Benchmark output saved to ${output}"
