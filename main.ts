// Brainrot Rush entry program (Node 22, standard library only).
// Hands the game in: copies game.rbxl, src/, screenshots/ and PLAY.json
// from beside this file to /output, then writes /output/dossier.json with
// the vendored make.fun library (vendor/makefun-roblox.ts, the kit's copy).
//
// Run it locally with:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The grader fails any output name that starts with a dot (.gitkeep,
// .DS_Store, .git), so the recursive copies skip dotted names at every
// depth. Plain files at the root are copied by name and never dotted.
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(out, { recursive: true });

// Fail early with a clear message if the build was skipped: a missing
// game.rbxl would otherwise surface as a bare ENOENT from copyFileSync.
for (const needed of ['game.rbxl', 'PLAY.json']) {
  if (!existsSync(join(here, needed))) {
    throw new Error(`missing ${needed}: run "rojo build default.project.json --output game.rbxl" first`);
  }
}
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
}

// buildDossier reads game.rbxl, src/ and screenshots/ from the output
// directory and writes the summary the judge reads. The caps mirror the
// gate's own (see the competition's rules): only text_max_bytes shapes the
// bytes; the others refuse an entry the scorer would refuse.
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
